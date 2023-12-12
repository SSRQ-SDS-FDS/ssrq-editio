/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./../../../**/*.{html,xqm,xql}"],
  darkMode: "media",
  theme: {
    extend: {
      colors: {
        "ssrq-primary": "#961A17" /* angepasst an Farbwert im PNG-Logo */,
        "ssrq-secondary": "#e1e1de",
        "ssrq-alt": {
          50: "#f5f5f3",
          100: "#ebebe7",
          200: "#ccccbf",
          300: "#adad97",
          400: "#8f8f6f",
          500: "#c6c6b6",
          600: "#a3a38d",
          700: "#808064",
          800: "#5d5d3b",
          900: "#3a3a12",
        },
        "ssrq-greyed": {
          50: "#f5f5f5",
          100: "#ebebeb",
          200: "#d1d1d1",
          300: "#b7b7b7",
          400: "#9d9d9d",
          500: "#b5b5b5",
          600: "#797979",
          700: "#5f5f5f",
          800: "#454545",
          900: "#2b2b2b",
        },
      },
    },
    fontFamily: {
      monospace: [
        "ui-monospace",
        "SFMono-Regular",
        "Menlo",
        "Monaco",
        "Consolas",
        "Liberation Mono",
        "Courier New",
        "monospace",
      ],
      sans: ["Open Sans", "Verdana", "Helvetica", "sans-serif"],
      seris: ["Lexia Fontes", "Georgia", "Times New Roman", "serif"],
    },
  },
  plugins: [require("@tailwindcss/forms")],
};
