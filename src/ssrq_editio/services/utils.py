def normalize(text: str | None):
    if text is None:
        return None
    return text.strip()
