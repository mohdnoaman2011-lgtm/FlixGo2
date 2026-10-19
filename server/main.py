"""FlixGo API: يشغّل yt-dlp على الخادم ويقدّم الملفات لتطبيق Flutter."""
import os
import tempfile
import threading
import uuid
from typing import Optional

import yt_dlp
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel

app = FastAPI(title="FlixGo API")
DL_DIR = os.path.join(tempfile.gettempdir(), "flixgo")
os.makedirs(DL_DIR, exist_ok=True)
JOBS: dict = {}


class DownloadReq(BaseModel):
    url: str
    mode: str = "video"  # video | audio
    height: Optional[int] = 0  # 0 = أفضل جودة


def _run(job_id: str, req: DownloadReq) -> None:
    job = JOBS[job_id]
    audio = req.mode == "audio"

    def hook(d):
        if d["status"] == "downloading":
            total = d.get("total_bytes") or d.get("total_bytes_estimate") or 0
            done = d.get("downloaded_bytes", 0)
            job["progress"] = min(done / total, 0.99) if total else 0
            job["speed"] = d.get("speed") or 0
        title = (d.get("info_dict") or {}).get("title")
        if title:
            job["title"] = title

    opts = {
        "outtmpl": os.path.join(DL_DIR, f"{job_id}.%(ext)s"),
        "noplaylist": True,
        "quiet": True,
        "no_color": True,
        "progress_hooks": [hook],
    }
    if audio:
        opts["format"] = "bestaudio/best"
        opts["postprocessors"] = [
            {"key": "FFmpegExtractAudio", "preferredcodec": "mp3", "preferredquality": "192"}
        ]
    else:
        h = req.height or 0
        flt = f"[height<={h}]" if h else ""
        opts["format"] = f"bestvideo{flt}+bestaudio/best{flt}/best"
        opts["merge_output_format"] = "mp4"

    try:
        with yt_dlp.YoutubeDL(opts) as y:
            info = y.extract_info(req.url, download=True)
        job["title"] = info.get("title") or job.get("title") or "media"
        path = os.path.join(DL_DIR, f"{job_id}.{'mp3' if audio else 'mp4'}")
        if not os.path.exists(path):
            found = [
                f for f in os.listdir(DL_DIR)
                if f.startswith(job_id + ".") and not f.endswith((".part", ".ytdl"))
            ]
            if not found:
                raise RuntimeError("لم يتم العثور على الملف الناتج")
            path = os.path.join(DL_DIR, found[0])
        job.update(status="done", progress=1.0, path=path)
    except Exception as e:  # noqa: BLE001
        job.update(status="error", error=str(e)[:300])


@app.post("/download")
def start(req: DownloadReq):
    if not req.url.startswith("http"):
        raise HTTPException(400, "رابط غير صالح")
    job_id = uuid.uuid4().hex[:12]
    JOBS[job_id] = {"status": "running", "progress": 0.0, "speed": 0, "title": None, "error": None}
    threading.Thread(target=_run, args=(job_id, req), daemon=True).start()
    return {"id": job_id}


@app.get("/jobs/{job_id}")
def job_status(job_id: str):
    j = JOBS.get(job_id)
    if not j:
        raise HTTPException(404, "المهمة غير موجودة")
    return {k: j.get(k) for k in ("status", "progress", "speed", "title", "error")}


@app.get("/file/{job_id}")
def get_file(job_id: str):
    j = JOBS.get(job_id)
    if not j or j.get("status") != "done":
        raise HTTPException(404, "الملف غير جاهز")
    return FileResponse(j["path"], filename=os.path.basename(j["path"]))
