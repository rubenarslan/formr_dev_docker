# after installing new packages, check whether any new packages conflict
# with OpenCPU basics. Only remove a site-library copy when it is NOT newer
# than the system one: deleting a newer copy (e.g. rlang) leaves dependents
# installed against it broken ("namespace 'rlang' 1.1.6 is already loaded,
# but >= 1.1.7 is required"), because OpenCPU preloads from the system lib.
ocpubasics <- installed.packages(lib = "/usr/lib/R/library")
userpkgs <- installed.packages(lib = "/usr/local/lib/R/site-library")
dupes <- intersect(rownames(userpkgs), rownames(ocpubasics))
to_remove <- dupes[package_version(userpkgs[dupes, "Version"]) <=
                   package_version(ocpubasics[dupes, "Version"])]
print("Removed duplicate packages (site copy not newer than system copy)")
print(to_remove)
if (length(to_remove) > 0) {
  remove.packages(to_remove, lib = "/usr/local/lib/R/site-library")
}
