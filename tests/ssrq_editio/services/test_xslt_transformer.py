from concurrent.futures import ThreadPoolExecutor

from saxonche import PySaxonProcessor

from ssrq_editio.services.xslt.transformer import (
    XSLTParam,
    apply_precompiled_xslt,
)


def test_precompiled_xslt_isolates_parameters_between_threads():
    stylesheet = """
        <xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
            <xsl:output method="text"/>
            <xsl:param name="value"/>
            <xsl:template match="/">
                <xsl:value-of select="$value"/>
            </xsl:template>
        </xsl:stylesheet>
    """
    processor = PySaxonProcessor(license=False)
    executable = processor.new_xslt30_processor().compile_stylesheet(stylesheet_text=stylesheet)

    def transform(value: str) -> str | None:
        return apply_precompiled_xslt(
            "<root/>",
            processor,
            executable,
            params=[XSLTParam("value", value)],
        ).value

    expected = [str(index) for index in range(100)]
    with ThreadPoolExecutor(max_workers=8) as executor:
        result = list(executor.map(transform, expected))

    assert result == expected
