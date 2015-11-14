# -*- encoding: utf-8 -*-
__author__ = 'medvedev.ivan@mail.ru'

from dbfread import DBF
from collections import namedtuple
import psycopg2
import os, json

#DATA_TYPES = {
#	'\+': {'name': 'autoincrement', 'pgtype': 'serial'},
#	'@': {'name': 'time', 'pgtype': 'timestamp'},
#	'0': {'name': 'flags', 'pgtype': 'text'},
#	'B': {'name': 'double', 'pgtype': 'float'},
#	}

FIAS_TABLE_NAMES = ['addrobj','house','houseint','landmark','nordoc','socrbase','curentst','actstat','operstat','centerst','intvstat','hststat','eststat','strstat','daddrobj','dhouse','dhouseint','dlandmark','dnordoc']

class config:
	config_file = ''
	config_data = {}

	def __init__(self,config_file):
		self.config_file = config_file

	def load_from_file(self):
		conf = open(self.config_file,'r')
		self.config_data = json.load(conf)
		conf.close()


class pgworker:
	host = 'localhost'
	port = '5432'
	dbname = 'fias'
	user = ''
	password = ''
	schema = {}

	def __init__(self,dbname,user,password,host='localhost',port='5432'):
		self.host = host
		self.port = port
		self.dbname = dbname
		self.user = user
		self.password = password

	def __connect(self):
		return psycopg2.connect(database=self.dbname,user=self.user,password=self.password,host=self.host,port=self.port)

	def get_schema(self):
		pass

	def load_schema(self):
		pass

	def update_schema(self):
		pass

	def upsert_data(self,tablename,data):
		pass

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
