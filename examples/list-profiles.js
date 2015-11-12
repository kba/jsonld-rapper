var JsonLD2RDF = require('../lib');
var j2r = new JsonLD2RDF();
for (profile in JsonLD2RDF.JSONLD_PROFILE) {
  console.log(profile + " =>\t'" + JsonLD2RDF.JSONLD_PROFILE[profile] + "'");
}
