from enum import Enum


class Lang(Enum):
    DE = "de"
    EN = "en"
    FR = "fr"
    IT = "it"

    @classmethod
    def from_string(cls, lang: str) -> "Lang":
        """Creates a Lang enum from a string. If
        the string is not recognized, the default
        language (de) is returned.

        Args:
            lang (str): The language string

        Returns:
            Lang: The corresponding Lang enum
        """
        match lang:
            case "de" | "deu":
                return cls.DE
            case "en" | "eng":
                return cls.EN
            case "fr" | "fra":
                return cls.FR
            case "it" | "ita":
                return cls.IT
            case _:
                return cls.DE
