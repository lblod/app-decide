#!/usr/bin/env python3
import argparse
import time
import sys

from config import get_datasets, get_organizations
from lib.generate_datadump import generate_datadump
from lib.generate_shacl import generate_shacl
from lib.generate_dcat import generate_dcat

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate a datadump (.ttl) for a configured dataset of an organization and write DCAT metadata to the triple store for discovery.",
        epilog="Example: mu script project-scripts publish-dataset --dataset codelists --org gent",
    )
    parser.add_argument("--dataset",  help="Dataset to process")
    parser.add_argument("--org", help="Organization to download datasets for")
    parser.add_argument("--list", action="store_true", help="List available datasets and organizations")
    parser.add_argument("--skip-dcat", action="store_true", help="Only generate the datadump; skip writing DCAT metadata to the triple store")
    args = parser.parse_args()

    if args.list and (args.dataset or args.org):
        parser.error("--list cannot be combined with --dataset or --org")
    if (args.dataset and not args.org) or (args.org and not args.dataset):
        parser.error("--dataset and --org must be used together")

    datasets = get_datasets()
    organizations = get_organizations()

    if args.list:
        print("Available datasets:")
        for name, dataset in datasets.items():
            print(f"  {name:30s}  {dataset['description']}")
        print("\nAvailable organizations:")
        for name, org in organizations.items():
            print(f"  {name:30s}  {org['catalog_publisher']['name']}")
        sys.exit(0)

    if args.dataset not in datasets:
        sys.exit(f"[Error] Unknown dataset '{args.dataset}'. Run with --list to see available datasets.")
    if args.org not in organizations:
        sys.exit(f"[Error] Unknown organization '{args.org}'. Run with --list to see available organizations.")

    dataset_config = datasets[args.dataset]
    organization_config = organizations[args.org]

    now = time.strftime("%Y%m%d%H%M%S")
    generate_datadump(now, args.dataset, dataset_config, organization_config)

    if not args.skip_dcat:
        generate_dcat(now, args.dataset, dataset_config, args.org, organization_config)
        generate_shacl(now, args.dataset, dataset_config, args.org, organization_config)
