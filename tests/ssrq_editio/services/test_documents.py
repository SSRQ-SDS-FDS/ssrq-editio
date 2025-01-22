from pathlib import Path

import pytest

from ssrq_editio.models.documents import Document
from ssrq_editio.services.documents import extract_infos_from_xml


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("xml_name", "document"),
    [
        (
            "SSRQ-SG-III_4-63-1.xml",
            Document(
                uuid="d56f1ce8-cec9-49ed-b54b-09f397adc2d8",
                idno="SSRQ-SG-III_4-63-1",
                is_main=True,
                sort_key=63,
                de_orig_date="1473 April 26 a. S.",
                en_orig_date="1473 April 26 O.S.",
                fr_orig_date="1473 avril 26 a. s.",
                it_orig_date="1473 aprile 26 v. s.",
                facs=["OGA_Gams_Nr_5_r", "OGA_Gams_Nr_5_v"],
                printed_idno="SSRQ SG III/4 63",
                volume_id=1,
                orig_place="loc000211",
                de_title="<h3>Stiftungsbrief einer Frühmesspfründe am Altar der Heiligen Drei Könige und des heiligen Jodok in der Pfarrkirche Gams von Andreas Roll von Bonstetten, Herr von Hohensax-Gams</h3>",
                fr_title=None,
            ),
        ),
        (
            "SDS-NE-1-143-1.xml",
            Document(
                uuid="8eb3d575-762e-4876-aa7e-546ae612480b",
                idno="SDS-NE-1-143-1",
                is_main=True,
                sort_key=143,
                de_orig_date="1708 Oktober 1",
                en_orig_date="1708 October 1",
                fr_orig_date="1708 octobre 1",
                it_orig_date="1708 ottobre 1",
                facs=[
                    "AEN_AS_O27_1_Ir",
                    "AEN_AS_O27_1_1r",
                    "AEN_AS_O27_1_1v_2r",
                    "AEN_AS_O27_1_1v_2r",
                    "AEN_AS_O27_1_2v_3r",
                    "AEN_AS_O27_1_2v_3r",
                    "AEN_AS_O27_1_3v_4r",
                    "AEN_AS_O27_1_3v_4r",
                    "AEN_AS_O27_1_4v_5r",
                    "AEN_AS_O27_1_4v_5r",
                    "AEN_AS_O27_1_5v_6r",
                    "AEN_AS_O27_1_5v_6r",
                    "AEN_AS_O27_1_6v_7r",
                    "AEN_AS_O27_1_6v_7r",
                    "AEN_AS_O27_1_7v_8r",
                    "AEN_AS_O27_1_7v_8r",
                    "AEN_AS_O27_1_8v",
                ],
                printed_idno="SDS NE 1 143",
                volume_id=1,
                orig_place="loc016171",
                de_title=None,
                fr_title="<h3>Articles généraux (points de franchises) octroyées par Frédéric 1<sup>er</sup>, roi de Prusse à tout l'État</h3>",
            ),
        ),
    ],
)
async def test_extract_infos_from_xml(
    example_path: Path, xml_name: str, document: Document, transpiled_schema: Path
):
    result = await extract_infos_from_xml(
        (example_path / xml_name,), 1, transpiled_schema=transpiled_schema
    )

    assert result[0] == document
