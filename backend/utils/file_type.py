def detect_file_type(ext):
    ext = ext.lower()
    if ext in ["jpg", "jpeg", "png", "gif", "bmp", "webp"]:
        return "images"
    elif ext in ["mp4", "mov", "avi", "mkv"]:
        return "videos"
    elif ext in ["mp3", "wav", "aac", "flac"]:
        return "audios"
    elif ext in ["pdf", "docx", "xlsx", "pptx", "txt"]:
        return "documents"
    else:
        return "raw_files"
