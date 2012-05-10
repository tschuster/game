CONFIG = YAML.load_file(Rails.root.join('config/values.yml')) rescue {}
EQUIPMENT = YAML.load_file(Rails.root.join('config/equipment.yml')) rescue {}