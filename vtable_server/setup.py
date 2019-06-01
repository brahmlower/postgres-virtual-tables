from setuptools import setup

setup(
    name = 'vtables-server',
    version = '0.1.0',
    description = 'Server for accessing and managing vtables',
    author = 'Brahm Lower',
    author_email = 'bplower@gmail.com',

    packages = ['vtables_server', 'vtables_server.domain'],
    package_dir = {'vtables_server': 'src'},
    install_requires = [
        'Flask==1.0.2',
        'PyYAML==3.13',
        'psycopg2-binary==2.7.7',
        'flask-sqlalchemy==2.3.2',
        'requests==2.21.0',
    ]
)
