# -*- encoding: utf-8 -*-
__author__ = 'medvedev.ivan@mail.ru'

from dbfread import DBF
from collections import namedtuple
import psycopg2, os

#DATA_TYPES = {
#	'\+': {'name': 'autoincrement', 'pgtype': 'serial'},
#	'@': {'name': 'time', 'pgtype': 'timestamp'},
#	'0': {'name': 'flags', 'pgtype': 'text'},
#	'B': {'name': 'double', 'pgtype': 'float'},
#	}

FIAS_TABLE_NAMES = ['addrobj','house','houseint','landmark','nordoc','socrbase','curentst','actstat','operstat','centerst','intvstat','hststat','eststat','strstat','daddrobj','dhouse','dhouseint','dlandmark','dnordoc']

class dbfreader:
	files_path=''
	encoding='cp866'
	schema = {}

	def __init__(self,path,encoding='cp866'):
		self.files_path = path
		self.encoding = encoding

	def __read_schema(filename,encoding='cp866'):
		d_file = DBF(filename, encoding = encoding, ignore_missing_memofile=True)
		return

	def touch(self):
		if os.path.exists(self.files_path):
			for dbf in [d for d in os.listdir(self.files_path) if d.lower().endswith('.dbf')]:
				
				data[os.path.basename(dbf).split('.')[0]]
