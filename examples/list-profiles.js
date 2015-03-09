var JsonLD2RDF = require('../lib/');
var j2r = new JsonLD2RDF();
for (profile in j2r.JSONLD_PROFILE) {
  console.log(profile + " =>\t'" + j2r.JSONLD_PROFILE[profile] + "'");
}
