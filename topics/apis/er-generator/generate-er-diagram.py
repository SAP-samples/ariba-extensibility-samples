import json
import argparse
from eralchemy import render_er

METADATA_FILE = "AnalyticalReporting.json"

def generate_er_markdown(entities = None):
    
    with open(METADATA_FILE) as f:
        ar_structure = json.load(f)

    output = ""
    relationships = []

    for document in ar_structure:
        document_md = ""
        document_type = document['documentType']

        if entities is None or document_type in entities:
            document_md = f"[{document_type}] \n"
            primary_keys = []
            filters = []
            
            # Process filters
            for filter in document['filterFields']:
                filters.append(filter['name'])
            
            # Process primary keys
            if 'primaryKeys' in document:
                for pk in document['primaryKeys']:
                    primary_keys.append(pk['name'])

            # Get all fields
            for field in document['selectFields']:
                field_name = field['name']
                field_type = field['type']

                prefix = ""
                suffix = ""

                if field_name in primary_keys:
                    prefix = "*"
                
                if field_name in filters:
                    suffix = "*"

                fk_entity = ""
                if field_type.endswith("Dim"):

                    # Only add FK prefix if it is not a primary key
                    if field_name not in primary_keys:
                        prefix = "+"
                    fk_entity = f' {{label:"{field_type}"}}'
                    relationships.append((document_type, "1--1", field_type))
                else:
                    fk_entity = f' {{label:"{field_type}"}}'
                
                document_md += f"{prefix}{field_name}{suffix}{fk_entity}\n"

            output += document_md + "\n"

    for rel in set(relationships):
        rel_str = f"{rel[0]} {rel[1]} {rel[2]}\n"
        output += rel_str
    
    return output
    
def document_type_entities(doc_type):
    with open(METADATA_FILE) as f:
        ar_structure = json.load(f)

    entities = []

    for document in ar_structure:
        document_type = document['documentType']

        if doc_type == document_type:
            entities.append(doc_type)

            for field in document['selectFields']:
                # print(f'{field["name"]},{field["type"]}')
                # print(f'"{field["name"]}",')
                field_type = field['type']

                if field_type.endswith("Dim"):
                    entities.append(field_type)
    
    return entities


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='SAP Ariba ER Diagram generator')

    parser.add_argument('--document_type', type=str, default='',
                        help='Example value: S4ApprovalFlowFact')
    
    args = parser.parse_args()
    
    er_markdown = ""

    if args.document_type != "":
        er_markdown = generate_er_markdown(document_type_entities(args.document_type))
    else:
        er_markdown = generate_er_markdown()

    # Generate output file name
    document_filename = "_" + args.document_type if args.document_type != "" else ""
    er_markdown_filename = f"analytical_reporting{document_filename}"

    # Store Entity Relationship markdown
    with open(er_markdown_filename + ".er", "w") as f:
        f.write(er_markdown)
    
    ## Draw from Entity Relationship markdown to PDF
    render_er(er_markdown_filename + ".er", er_markdown_filename + ".pdf")
