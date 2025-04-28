from aiosqlite import Connection
from fastapi import Request
from ssrq_utils.lang.display import Lang

from ssrq_editio.entrypoints.app.views.models.base import ViewContext, ViewModel
from ssrq_editio.models.kantons import KantonName
from ssrq_editio.models.volumes import Volume
from ssrq_editio.services.volumes import get_volume_info


class DocumentViewModel(ViewModel):
    """This View Model is used to display documents."""

    connection: Connection
    volume_info: Volume | None = None

    def __init__(
        self,
        request: Request,
        lang: Lang,
        connection: Connection,
        kanton: KantonName,
        volume: str,
        document: str,
    ):
        super().__init__(request, lang)
        self.page = "document.jinja"
        self.connection = connection
        self.kanton = kanton
        self.volume = volume
        self.document = document

    async def create_context(self) -> ViewContext:
        if self.volume_info is None:
            self.volume_info = await get_volume_info(self.connection, self.kanton, self.volume)
        return ViewContext(
            request=self.request,
            lang=self.lang,
            data={
                "page_title": self._get_title(),
                "page_description": self._get_description(),
                "content": {
                    "kanton": self.kanton.value,
                    "volume": self.volume_info,
                    "document": self.document,
                    "document_info": {
                        "printed_idno": "SSRQ SG III/4 1",
                        "de_orig_date": "1050 Juli 12 a. S.",
                    },
                    "orig_places": ["Nattheim"],
                    "title": "Eid der Säckelmeister der Stadt Zürich",
                    "document_prev": "prev",
                    "document_next": "next",
                    "left_col": [
                        transcription_dummy,
                        edition_dummy,
                        tei_dummy,
                    ],
                    "right_col": [
                        description_dummy,
                        digital_dummy,
                        regest_dummy,
                        comment_dummy,
                        entities_dummy,
                    ],
                },
            },
            translator=self.translator,
        )

    def _get_title(self) -> str:
        return f"{self.translator.translate(self.lang, 'short_title')} · {self.kanton.value} {self.volume_info.name if self.volume_info else self.volume}"


# https://editio.ssrq-online.ch/ZH/NF_I_1_3/2-1.html?odd=ssrq.odd
transcription_dummy = {
    "tab": "transcript",
    "template": "DocumentTranscriptionCard.jinja",
    "context": {
        "title": "Der eid, den die swerren soͤllend, so zuͦ unsern secklern<br />genomen werden",
        "document": "Item welich zuͦ b secklern genomen werdent, soͤllend swerren, c–der statt schulden<br /> und zinß–c, die in dz d seckelampt und dar zuͦ dienend und gehoͤrend und inen<br /> ingeschrift geben werdent, inzeziechend zuͦ unser gemeinen statt handen und<br /> die zinß und anders, so uff dem seckelampt statt und inen bevolhen wirt<br /> usszegebend, da von und dar uss ze bezallend und ze gebend, so verr das mag<br /> gelangen. Und ob u̍tzit fu̍rschusse, dz zuͦ gemeiner statt handen ze behaltend<br /> und in gemeiner statt nutz ze bekerend und dar inn unser gemeinen statt<br /> nutz unnd ere fuͤrdren und schaden wenden, so verr sy kunnend oder mugend,<br /> e f–und jerlich von irem innemen und ussgeben<br /> rechnung geben, als das von alter herr komen ist, alles getruwlich und ungefaͧrlich.–f g<br />",
    },
}
edition_dummy = {
    "tab": "edition_text",
    "template": "DocumentTranscriptionCard.jinja",
    "context": {
        "title": "Der eid, den die swerren soͤllend, so zuͦ unsern secklern genomen werden",
        "document": "Item welich zuͦ b secklern genomen werdent, soͤllend swerren, c–der statt schulden und zinß–c, die in dz d seckelampt und dar zuͦ dienend und gehoͤrend und inen ingeschrift geben werdent, inzeziechend zuͦ unser gemeinen statt handen und die zinß und anders, so uff dem seckelampt statt und inen bevolhen wirt usszegebend, da von und dar uss ze bezallend und ze gebend, so verr das mag gelangen.<br />Und ob u̍tzit fu̍rschusse, dz zuͦ gemeiner statt handen ze behaltend und in gemeiner statt nutz ze bekerend und dar inn unser gemeinen statt nutz unnd ere fuͤrdren und schaden wenden, so verr sy kunnend oder mugend, e f–und jerlich von irem innemen und ussgeben rechnung geben, als das von alter herr komen ist, alles getruwlich und ungefaͧrlich.–f g",
    },
}
tei_dummy = {
    "tab": "tei_xml",
    "template": "DocumentTranscriptionCard.jinja",
    "context": {"title": "", "document": "TEI-XML..."},
}
description_dummy = {
    "tab": "description",
    "template": "DocumentTranscriptionCard.jinja",
    "context": {
        "title": "",
        "document": "Signatur: StAZH B II 4, Teil II, fol. 19v, Eintrag 1<br />Originaldatierung: ca. 1447 – 1450 (Datierung aufgrund der Schreiberhand)<br />Überlieferung: Eintrag<br />Beschreibstoff: Papier<br />Format B × H (cm): 30.5 × 40.0<br />Sprache: Deutsch<br />Edition<br /><br />Zürcher Stadtbücher, Bd. 3/2, S. 188, Nr. 89",
    },
}
digital_dummy = {
    "tab": "digital_copy",
    "template": "DocumentPicture.jinja",
    "context": {
        "title_sources": "https://facsimiles.ssrq-sds-fds.ch/iiif/2/StAZH_B_III_2__353.ptif/info.json"
    },
}
regest_dummy = {
    "tab": "summary",
    "template": "DocumentTranscriptionCard.jinja",
    "context": {"title": "", "document": "Regest..."},
}
comment_dummy = {
    "tab": "comment",
    "template": "DocumentTranscriptionCard.jinja",
    "context": {"title": "", "document": "Kommentar..."},
}
entities_dummy = {
    "tab": "entities",
    "template": "DocumentTranscriptionCard.jinja",
    "context": {"title": "", "document": "Entitäten..."},
}
