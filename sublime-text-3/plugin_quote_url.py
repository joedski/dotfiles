import urllib
import sublime
import sublime_plugin


class QuoteUrlCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        selections = [(r, self.view.substr(r)) for r in self.view.sel()]
        selections.reverse()
        for (selection_region, selection_text) in selections:
            quoted_text = urllib.parse.quote(selection_text)
            self.view.replace(edit, selection_region, quoted_text)
