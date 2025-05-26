from typing import cast

from jinja2 import pass_context
from jinja2.runtime import Context
from markupsafe import Markup

__all__ = ["render_template_string"]


@pass_context
def render_template_string(context: Context, value: str) -> Markup:
    """
    Render a Jinja2 template string with the given context.

    Args:
        context (Context): The Jinja2 context containing variables.
        value (str): The template string to render.

    Returns:
        Markup: The rendered template as a Markup object.
    """
    _template = context.eval_ctx.environment.from_string(value)
    result = _template.render(**context)
    if context.eval_ctx.autoescape:
        result = Markup(result)
    return cast(Markup, result)
