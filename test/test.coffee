Async = require 'async'
util = require 'util'
test = require 'tape'
jsonld = require 'jsonld'

JsonldRapper = require('../src')
DEBUG=false
# DEBUG=true

jsonld1 = {
	'@context': {
		"foaf": "http://xmlns.com/foaf/0.1/"
	},
	'@id': 'urn:fake:johndoe'
	'foaf:firstName': 'John'
}
jsonld1_withoutContext = {
	'@id': 'urn:fake:johndoe'
	'foaf:firstName': 'John'
}
turtle1 = '''@base <http://example.com/FIXME/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<urn:fake:johndoe>
    <http://xmlns.com/foaf/0.1/firstName> "John" .
'''
turtle1_withoutPrefixes = '''
<urn:fake:johndoe>
    foaf:firstName "John" .
'''
bare_rdfxml = '''
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
	<rdf:Description rdf:about="urn:fake:johndoe">
		<foaf:firstName>John</foaf:firstName>
	</rdf:Description>
</rdf:RDF>
'''

testJSONLD_RDF_ok = (t) ->
	j2r = new JsonldRapper()
	console.log j2r.convert

	okConversions = [
		['jsonld', 'turtle', '@prefix']
		['guess',  'rdfxml', 'rdf:RDF']
		['guess',  'dot', 'digraph']
		['guess',  'html', '<html']
		['guess',  'nquads', '<urn']
		['guess',  'json-triples', '"triples"']
		['guess',  'json', '"value"']
		['guess',  'dot', 'digraph']
	]
	Async.map okConversions, (pair, cb) ->
		[from, to, detect] = pair
		j2r.convert jsonld1, from, to, (err, converted) ->
			t.notOk err, "No error #{from}->#{to}"
			t.ok converted.indexOf(detect) > -1, "Converted result contains '#{detect}' for #{from}->#{to}"
			cb()
	, () -> t.end()

testJSONLD_RDF_notOk = (t) ->
	j2r = new JsonldRapper()

	notOkConversions = [
		['jsonld',  'atom', 'No RSS channel']
	]

	Async.map notOkConversions, (pair, cb) ->
		[from, to, expect] = pair
		j2r.convert jsonld1, from, to, (err, converted) ->
			t.ok err, "Expect an error for #{from}->#{to}"
			t.ok err.cause?.indexOf(expect) > -1, "Expected error found"
			cb null
	, () -> t.end()

testRDF_JSON_ok = (t) ->
	j2r = new JsonldRapper()

	oks = [
		['turtle', 'jsonld', '@id']
	]
	Async.map oks, (pair, cb) ->
		[from, to, detect] = pair
		j2r.convert turtle1, from, to, (err, converted) ->
			t.notOk err, "No error #{from}->#{to}"
			t.ok JSON.stringify(converted).indexOf(detect) > -1, "Converted result contains '#{detect}' for #{from}->#{to}"
			cb()
	, () -> t.end()

testRDF_RDF_ok = (t) ->
	j2r = new JsonldRapper()

	oks = [
		['turtle', 'nquads', '<urn']
		['turtle', 'rdfxml', 'rdf:RDF']
	]
	Async.map oks, (pair, cb) ->
		[from, to, detect] = pair
		j2r.convert turtle1, from, to, (err, converted) ->
			t.notOk err, "No error #{from}->#{to}"
			t.ok JSON.stringify(converted).indexOf(detect) > -1, "Converted result contains '#{detect}' for #{from}->#{to}"
			# console.log converted
			cb()
	, () -> t.end()

testJSONLD_RDF_PREFIX = (t) ->
	j2r = new JsonldRapper(
		expandContext:
			foaf: 'http://xmlns.com/foaf/0.1/'
	)
	okConversions = [
		[jsonld1, 'jsonld', 'turtle', 'foaf:firstName ']
		[jsonld1_withoutContext, 'jsonld', 'turtle', 'foaf:firstName ']
		[turtle1, 'turtle', 'jsonld', '/firstName']
		[turtle1_withoutPrefixes, 'turtle', 'jsonld', '/firstName']
		[bare_rdfxml, 'rdfxml', 'turtle', 'foaf:firstName ']
	]
	Async.map okConversions, (tuple, cb) ->
		[doc, from, to, detect] = tuple
		j2r.convert doc, from, to, (err, converted) ->
			t.notOk err, "No error #{from}->#{to}"
			asString = if typeof converted is 'object' then JSON.stringify(converted) else converted
			# console.log asString
			t.ok asString.indexOf(detect) > -1, "Converted result contains '#{detect}' for #{from}->#{to}"
			cb()
	, () -> t.end()

test "JSONLD -> RDF  ==  OK", testJSONLD_RDF_ok
test "JSONLD -> RDF  ==  FAIL", testJSONLD_RDF_notOk
test "RDF -> JSONLD  ==  OK", testRDF_JSON_ok
test "RDF -> RDF  ==  OK", testRDF_RDF_ok
test "JSONLD -> RDF  (Prefixes)", testJSONLD_RDF_PREFIX

# test.only 'bla', (t) ->
	# console.log bare_rdfxml.replace('>', ' xmlns:bla="foo"$&')

# ALT: src/index.coffee
