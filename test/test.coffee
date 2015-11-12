Async = require 'async'
util = require 'util'
test = require 'tape'
jsonld = require 'jsonld'
Colors = require 'colors'

JsonldRapper = require('../src')
DEBUG=false
# DEBUG=true

testConversions = (t, ok, notOk) ->
	j2r = new JsonldRapper
		expandContext: 
			foaf: 'http://xmlns.com/foaf/0.1/'
	ok or= []
	notOk or= []
	Async.series [
		(cb) ->
			Async.eachSeries ok, ([input, from, to, detect], done) ->
				j2r.convert input, from, to, (err, data) ->
					data = JSON.stringify(data) unless typeof data is 'string'
					t.notOk err, "No error #{from}->#{to}"
					unless data.indexOf(detect) > -1
						console.log data.red if DEBUG
						t.fail "Conversion doesn't contain '#{detect}' for #{from}->#{to}"
					else if DEBUG
						console.log data.green if DEBUG
					done()
			, cb
		,
		(cb) ->
			Async.each notOk, ([input, from, to, expect], done) ->
				j2r.convert input, from, to, (err, data) ->
					t.ok err, "Expect error '#{expect}' for #{from}->#{to}"
					unless err.cause?.indexOf(expect) > -1
						console.log "Wrong error "
						console.log err
					done()
			, cb()
		], () -> t.end()
_test = (title, ok, notOk) -> test title, (t) -> testConversions t, ok, notOk
_only = (title, ok, notOk) -> test.only title, (t) -> testConversions t, ok, notOk

fixtures =
	jsonld:
		'@context': {
			"foaf": "http://xmlns.com/foaf/0.1/"
		},
		'@id': 'urn:fake:johndoe'
		'foaf:firstName': 'John'
	jsonld_withoutContext: {
		'@id': 'urn:fake:johndoe'
		'foaf:firstName': 'John'
	}
	json3: [
		{
			subject: 'urn:fake:johndoe'
			predicate: 'foaf:firstName'
			object: '"John"'
		}
	]
	nquads: """
	<urn:fake:johndoe> <http://xmlns.com/foaf/0.1/firstName> "John" .
	"""
	turtle: '''@base <http://example.com/FIXME/> .
	@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
	<urn:fake:johndoe>
		<http://xmlns.com/foaf/0.1/firstName> "John" .
	'''
	turtle_withoutPrefixes: '''
	<urn:fake:johndoe>
		foaf:firstName "John" .
	'''
	bare_rdfxml: '''
	<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
		<rdf:Description rdf:about="urn:fake:johndoe">
			<foaf:firstName>John</foaf:firstName>
		</rdf:Description>
	</rdf:RDF>
	'''

JSONLD_OK = [
	[fixtures.jsonld, 'jsonld', 'turtle', '@prefix']
	[fixtures.jsonld, 'guess',  'rdfxml', 'rdf:RDF']
	[fixtures.jsonld, 'guess',  'dot', 'digraph']
	[fixtures.jsonld, 'guess',  'html', '<html']
	[fixtures.jsonld, 'guess',  'nquads', '<urn']
	[fixtures.jsonld, 'guess',  'json-triples', '"triples"']
	[fixtures.jsonld, 'guess',  'json', '"value"']
	[fixtures.jsonld, 'guess',  'dot', 'digraph']
]
JSONLD_NOTOK = [
	[fixtures.jsonld, 'jsonld', 'atom', 'No RSS channel']
]
RDF_OK = [
	[fixtures.turtle, 'turtle', 'jsonld', '@id']
	[fixtures.turtle, 'turtle', 'nquads', '<urn']
	[fixtures.turtle, 'turtle', 'rdfxml', 'rdf:RDF']
]
PREFIX_OK = [
	[fixtures.jsonld, 'jsonld', 'turtle', 'foaf:firstName ']
	[fixtures.jsonld_withoutContext, 'jsonld', 'turtle', 'foaf:firstName ']
	[fixtures.turtle, 'turtle', 'jsonld', '/firstName']
	[fixtures.turtle_withoutPrefixes, 'turtle', 'jsonld', '/firstName']
	[fixtures.bare_rdfxml, 'rdfxml', 'turtle', 'foaf:firstName ']
]
JSON3_OK = [
	[fixtures.json3, 'json3', 'json3', '"subject":']
	[fixtures.json3, 'json3', 'nquads', '"John"']
	[fixtures.json3, 'json3', 'turtle', '@prefix']
	[fixtures.json3, 'json3', 'jsonld', '@value']
	[fixtures.turtle, 'turtle', 'json3', '"subject":']
	[fixtures.nquads, 'nquads', 'json3', '"subject":']
]

_test "JSONLD", JSONLD_OK, JSONLD_NOTOK
_test "RDF", RDF_OK
_test "JSON3", JSON3_OK
_test "Prefixes", PREFIX_OK

# test.only 'bla', (t) ->
	# console.log bare_rdfxml.replace('>', ' xmlns:bla="foo"$&')

# ALT: src/index.coffee
