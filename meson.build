project('com.github.sapoturge.svg_editor', 'vala', 'c')

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

install_data(
    join_paths('data', meson.project_name() + '.desktop'),
    install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data(
    join_paths('data', meson.project_name() + '.appdata.xml'),
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)
