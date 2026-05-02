import json
import math

with open("tunnelnodes.geojson") as f:
    node_data = json.load(f)

with open("tunnelpaths.geojson") as f:
    path_data = json.load(f)

nodes = []
edges = []

node_ids = {}
node_count = 1

for feature in node_data["features"]:
    if feature["geometry"]["type"] == "Point":
        coords = feature["geometry"]["coordinates"]

        node_id = f"T{node_count:03}"
        node_ids[(round(coords[0], 6), round(coords[1], 6))] = node_id

        nodes.append({
            "id": node_id,
            "latitue": coords[1],
            "longitude": coords[0],
            "type": "tunnel"
        })

        node_count += 1

def distance(p1, p2):
    return math.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

for feature in path_data["features"]:
    if feature["geometry"]["type"] == "LineString":
        coords = feature["geometry"]["coordinates"]

        for i in range(len(coords) - 1):
            p1 = (round(coords[i][0], 6), round(coords[i][1], 6))
            p2 = (round(coords[i + 1][0], 6), round(coords[i + 1][1], 6))

            if p1 in node_ids and p2 in node_ids and node_ids[p1] != node_ids[p2]:
                edges.append({
                    "source": node_ids[p1],
                    "target": node_ids[p2],
                    "length": distance(p1, p2)
                })

with open("node.json", "w") as f:
    json.dump(nodes, f, indent=2)

with open("edge.json", "w") as f:
    json.dump(edges, f, indent=2)

print("node.json and edge.json created.")