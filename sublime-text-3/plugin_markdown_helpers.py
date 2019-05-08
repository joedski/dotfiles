import sublime
import sublime_plugin


class MarkdownSetextHeaderH1Command(sublime_plugin.TextCommand):
    def run(self, edit):
        lines = flatten([self.view.lines(region) for region in self.view.sel()])
        lines.reverse()
        for line in lines:
            full_line = self.view.full_line(line)
            end_class = self.view.classify(full_line.end())
            print('- {}'.format(end_class & sublime.CLASS_LINE_END))
