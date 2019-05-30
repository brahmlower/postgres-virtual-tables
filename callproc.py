import psycopg2
conn = psycopg2.connect(host='localhost', user='test', password='test')
conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
cur = conn.cursor()
# cur.callproc("testing_failing_function", [2, ['Hort', 'Ludwell', 'hludwell0@ow.ly', '+263 620 800 5590', 'False', '145']])
cur.callproc("testing_simple_insert", (['2', '2000', '3', 'BUTTS'],))

print(cur.fetchone())
# conn.commit()
cur.close()
conn.close()