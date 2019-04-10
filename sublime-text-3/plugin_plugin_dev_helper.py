import sublime
import sublime_plugin


class PluginDevHelperShowViewSelCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        print('Active View Selection Regions:')
        for region in self.view.sel():
            print('- [{} {}]'.format(
                region.begin(),
                region.end()
            ))
