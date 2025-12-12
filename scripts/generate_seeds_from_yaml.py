#!/usr/bin/env python3
"""
Convert enumeration YAML files to dbt seed CSVs
Usage: python scripts/generate_seeds_from_yaml.py
"""

import os
import yaml
import csv
from pathlib import Path

def convert_yaml_to_csv(yaml_file, output_dir):
    """Convert single YAML enumeration to CSV seed"""
    
    # Read YAML
    with open(yaml_file, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
    
    # Extract enumeration name (remove domain prefix)
    enum_name = data['enumeration_name']
    # Remove 'customer_' prefix for cleaner table names
    table_name = enum_name.replace('customer_', '')
    
    # Prepare output file
    output_file = output_dir / f"{table_name}.csv"
    
    # Extract values
    values = data.get('valid_values', [])
    
    if not values:
        print(f"⚠️  Warning: No values found in {yaml_file}")
        return
    
    # Write CSV
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['code', 'description', 'sort_order', 'is_active'])
        writer.writeheader()
        
        for value in values:
            writer.writerow({
                'code': value['code'],
                'description': value. get('description', value. get('display_name', '')),
                'sort_order': value.get('sort_order', 99),
                'is_active':  'TRUE'  # All active by default
            })
    
    print(f"✅ Generated:  {output_file} ({len(values)} rows)")

def main():
    # Paths
    yaml_dir = Path('enumerations')
    output_dir = Path('dbt/seeds/reference')
    
    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print("🔄 Converting YAML enumerations to CSV seeds.. .\n")
    
    # Process all YAML files
    yaml_files = list(yaml_dir.glob('*.yaml'))
    
    skip_files = [
    'README.yaml',
    'audit_event_types.yaml',
    'customer_profile_attribute_names.yaml',
    'customer_profile_audit_change_reason.yaml'
    ]

    for yaml_file in yaml_files: 
        if yaml_file.name in skip_files:
            print(f"⏭️  Skipping:  {yaml_file.name} (not needed for reference data)")
            continue
    
        try: 
            convert_yaml_to_csv(yaml_file, output_dir)
        except Exception as e:
            print(f"❌ Error processing {yaml_file}: {e}")
    
    print(f"\n✅ Complete! Generated {len(list(output_dir.glob('*. csv')))} CSV files")
    print(f"📁 Location: {output_dir}")
    print(f"\n🚀 Next step: Install PyYAML and run the script")

if __name__ == '__main__':
    main()