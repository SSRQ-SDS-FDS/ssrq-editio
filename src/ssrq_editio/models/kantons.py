from enum import Enum
from typing import Annotated

from pydantic import BaseModel, BeforeValidator


class KantonName(str, Enum):
    zh = "ZH"
    be = "BE"
    lu = "LU"
    ur = "UR"
    sz = "SZ"
    ow_nw = "OW-NW"
    gl = "GL"
    zg = "ZG"
    fr = "FR"
    so = "SO"
    bs = "BS"
    bl = "BL"
    sh = "SH"
    ar_ai = "AR-AI"
    sg = "SG"
    gr = "GR"
    ag = "AG"
    tg = "TG"
    ti = "TI"
    vd = "VD"
    vs = "VS"
    ne = "NE"
    ge = "GE"
    ju = "JU"

    def __str__(self):
        return self.value.replace("-", "/")


class Kanton(BaseModel):
    short_name: str
    de_title: str
    fr_title: str | None
    it_title: str | None
    docs: int
    filenames: Annotated[list[str], BeforeValidator(lambda x: x.split(","))]


class Kantons(BaseModel):
    kantons: tuple[Kanton, ...]
