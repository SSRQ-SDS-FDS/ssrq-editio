import logging
from typing import Any, Sequence, cast

from fastapi import Request
from jinja2 import pass_context
from jinja2.runtime import Context
from jinjax import Catalog
from markupsafe import Markup
from ssrq_utils.i18n.translator import Translator
from ssrq_utils.lang.display import Lang

from ssrq_editio.models.documents import Document
from ssrq_editio.models.entities import Entities, EntityTypes
from ssrq_editio.services.entities import map_to_entity_type

__all__ = ["create_entity_preview_by_id", "render_template_string", "display_sub_document_info"]


@pass_context
def render_template_string(context: Context, value: str, data: dict[str, Any] | None) -> Markup:
    """
    Render a Jinja2 template string with the given context.

    Args:
        context (Context): The Jinja2 context containing variables.
        value (str): The template string to render.

    Returns:
        Markup: The rendered template as a Markup object.
    """
    _template = context.eval_ctx.environment.from_string(value)
    result = _template.render(**context if data is None else {**context, **data})
    if context.eval_ctx.autoescape:
        result = Markup(result)
    return cast(Markup, result)


def create_entity_preview_by_id(
    component_catalog: Catalog,
    id: str,
    entities: dict[EntityTypes, Entities],
    lang: Lang,
    translator: Translator,
    request: Request,
) -> str:
    """
    This function is a utility, which will help us to create entity tooltips
    from the XSLT output processed by the templating engine of the web app. We will
    create a template string, which call's this function and is processed by jinja afterwards.
    Only the web app knows all the information about the entities, which we want to display
    in the frontend.

    Args:
        component_catalog (Catalog): The Jinja2 catalog to render the component. Passed by the context.
        id (str): The ID of the entity. Passed by the XSLT.
        entities (dict[EntityTypes, Entities]): The entities to search in. Passed by document view as property additional-data.
        lang (Lang): The language to use for rendering. Passed by document view as property additional-data.
        translator (Translator): The translator instance. Passed by document view as property additional-data.
        request (Request): The FastAPI request object. Passed by document view as property additional-data.

    Returns:
        str: The rendered HTML string for the entity preview / tooltip.
    """
    entity, entity_type = next(
        (
            (e, et)
            for et in map_to_entity_type(id)
            if (entity_store := entities.get(et)) is not None
            and (e := entity_store.get_by_id(id)) is not None
        ),
        (None, None),
    )
    if entity is None or entity_type is None:
        # Entry not found. Log error and return error message.
        # ToDo: Improve error logging
        logging.error("An error occurred while resolving id '%s'.", id)
        return "Something went wrong. Please contact support."

    return component_catalog.render(
        "EntityPreview",
        entity=entity,
        entity_type=entity_type.value,
        name=entity.get_name_by_lang(lang),
        lang=lang,
        translator=translator,
        request=request,
    )


def display_sub_document_info(sub_docs: Sequence[Document] | None, idno: str, lang: Lang) -> str:
    """
    Render a string with the title and original date of a sub document,
    if the given idno matches one of the sub documents.

    Args:
        sub_docs (Sequence[Document] | None): A list of sub documents to search in.
        idno (str): The idno of the sub document to find.
        lang (Lang): The language to use for the title.

    Returns:
        str: A string with the title and original date of the sub document, or an empty
    """
    if sub_docs is None:
        return ""

    sub_doc = next((doc for doc in sub_docs if doc.idno == idno), None)

    if sub_doc is None:
        return ""

    return Markup(
        f"{sub_doc.get_title_by_lang(lang)}, {getattr(sub_doc, f'{lang.value}_orig_date')}"
    )
