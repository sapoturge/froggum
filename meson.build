project('com.github.sapoturge.froggum', 'vala', 'c')

i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')

cc = meson.get_compiler('c')

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/widgets/EditorView.vala',
    'src/widgets/PathRow.vala',
    'src/widgets/Viewport.vala',
    'src/data/Image.vala',
    'src/data/Path.vala',
    'src/data/Segment.vala',
    'src/data/Point.vala',
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite'),
        cc.find_library('m', required: false)
    ],
    install: true
)

i18n.merge_file(
    input: join_paths('data', meson.project_name() + '.desktop.in'),
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

i18n.merge_file(
    input: join_paths('data', meson.project_name() + '.appdata.xml.in'),
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

subdir('po')
