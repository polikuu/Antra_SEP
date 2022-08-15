import json

with open('movie.json', 'r', encoding="utf8") as in_json_file:

    # Read the file and convert it to a dictionary
    data = json.load(in_json_file)

    total_length = len(data["movie"])
    increment = total_length // 8
    round = 0
    for i in range(0, total_length, increment):
        round += 1
        with open('NO'+str(i), 'w') as out_json_file:
            # Save each obj to their respective filepath
            # with pretty formatting thanks to `indent=4`
            if round == 8:
                json.dump(data['movie'][i:], out_json_file, indent=4)
                break
            json.dump(data['movie'][i:i+increment+1], out_json_file, indent=4)