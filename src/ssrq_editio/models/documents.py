from pydantic import BaseModel


class Document(BaseModel):
    uuid: str
    idno: str
    is_main: bool
    sort_key: int
    de_orig_date: str
    en_orig_date: str
    fr_orig_date: str
    it_orig_date: str
    facs: str | None
    printed_idno: str
    volume_id: int
    orig_place: str | None
    de_title: str | None
    fr_title: str | None
