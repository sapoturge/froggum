project('io.github.sapoturge.froggum', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

gresource_froggum = gnome.compile_resources(
    'gresource_froggum',
    join_paths('data', meson.project_name() + '.gresource.xml'),
    source_dir: 'data'
)

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')

cc = meson.get_compiler('c')

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/widgets/EditorView.vala',
    'src/widgets/Viewport.vala',
    'src/widgets/PatternButton.vala',
    'src/widgets/PatternChooserDialog.vala',
    'src/widgets/GradientEditor.vala',
    'src/widgets/Tutorial.vala',
    'src/data/Image.vala',
    'src/data/Path.vala',
    'src/data/Segment.vala',
    'src/data/Point.vala',
    'src/data/Pattern.vala',
    'src/data/Command.vala',
    'src/data/CommandStack.vala',
    'src/data/Undoable.vala',
    'src/data/Element.vala',
    'src/data/Circle.vala',
    'src/data/Group.vala',
    'src/data/Transform.vala',
    'src/data/Parser.vala',
    'src/data/Rectangle.vala',
    gresource_froggum,
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('libxml-2.0'),
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

install_data(
    join_paths('data', meson.project_name() + '.contract'),
    install_dir: join_paths(get_option('datadir'), 'contractor')
)

subdir('po')

icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('data', 'icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
    install_data(
        join_paths('data', 'icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps')
    )
endforeach

install_data(
    join_paths ('data', meson.project_name() + '.gschema.xml'),
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

meson.add_install_script('meson/post_install.py')
