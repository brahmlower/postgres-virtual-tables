from setuptools import setup

setup(
    name = 'vtable-lib',
    version = '0.1.0',
    description = 'Library for accessing and managing vtables',
    author = 'Brahm Lower',
    author_email = 'bplower@gmail.com',

    packages = ['vtable_lib'],
    package_dir = {'vtable_lib': 'src'},
    install_requires = [
        'sqlalchemy==1.3.4'
    ]
)
