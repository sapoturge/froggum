project('com.github.sapoturge.svg_editor', 'vala', 'c')

cc = meson.get_compiler('c')

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/EditorView.vala',
    'src/Image.vala',
    'src/Path.vala',
    'src/Segment.vala',
    'src/Color.vala',
    dependencies: [
        dependency('gtk+-3.0'),
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
