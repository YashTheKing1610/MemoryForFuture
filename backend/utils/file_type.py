# backend/utils/file_type.py

def detect_file_type(ext: str) -> str:
    """
    Detects the file type based on its extension and returns a
    singular category name: 'image', 'video', 'audio', 'document', or 'other'.
    """

    ext = ext.lower().lstrip(".")

    image_exts = {
        "jpg", "jpeg", "png", "gif", "bmp", "webp", "heic", "tiff", "svg"
    }
    video_exts = {
        "mp4", "mov", "mkv", "avi", "webm", "m4v", "mpeg", "3gp", "flv"
    }
    audio_exts = {
        "mp3", "wav", "aac", "m4a", "ogg", "oga", "flac", "opus", "m4b", "wma", "aiff"
    }
    document_exts = {
        "pdf", "txt", "doc", "docx", "rtf", "ppt", "pptx", "xls", "xlsx", "csv", "odt", "ods"
    }

    if ext in image_exts:
        return "image"
    if ext in video_exts:
        return "video"
    if ext in audio_exts:
        return "audio"
    if ext in document_exts:
        return "document"

    return "other"  # fallback for unknown extensions
