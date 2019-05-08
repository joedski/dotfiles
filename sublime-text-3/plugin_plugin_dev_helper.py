import sublime
import sublime_plugin


def flatten(list_of_lists):
    flattened_list = []
    for sub_list in list_of_lists:
        for item in sub_list:
            flattened_list.append(item)
    return flattened_list

class PluginDevHelperShowViewSelCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        print('Active View Selection Regions:')
        for region in self.view.sel():
            print('- [{} {}]'.format(
                region.begin(),
                region.end()
            ))

class PluginDevHelperShowSelectedLinesAndLineLengthsCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        print('Selected Lines and their Lengths:')
        lines = flatten([self.view.lines(region) for region in self.view.sel()])
        for line in lines:
            print('- [{} {}] {}'.format(
                line.begin(),
                line.end(),
                line.size()
            ))
