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
                facs=None,
                printed_idno="SSRQ SG III/4 63",
                volume_id=1,
                orig_place="loc000211",
                de_title=None,
                fr_title=None,
            ),
        )
    ],
)
async def test_extract_infos_from_xml(
    example_path: Path, xml_name: str, document: Document, transpiled_schema: Path
):
    result = await extract_infos_from_xml(
        (example_path / xml_name,), 1, transpiled_schema=transpiled_schema
    )
    print(result)
    assert result[0] == document
