import json

from flask import Flask, Response, make_response

from generate_er_diagram import generate_er_markdown, document_type_entities, generate_diagram

app = Flask(__name__)

@app.route('/documentTypes')
def document_types():
    entities = document_type_entities()
    
    return Response('{ "DocumentTypes": ' + json.dumps(sorted(entities)) + '}', mimetype='application/json')

@app.route('/documentTypes/<documentType>/diagram')
def documenty_type_diagram(documentType):

    if documentType in document_type_entities():
        diagram = generate_diagram(documentType)

        return Response(diagram, mimetype='application/pdf')
    
    return Response('{ "error": "Invalid document type" }', mimetype='application/json', status=404)