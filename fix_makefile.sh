#!/bin/bash
# Backup original
cp Makefile Makefile.backup

# Add OpenMP to compiler and linker flags
sed -i 's/^CXXFLAGS.*/CXXFLAGS=-std=c++11 -fopenmp/' Makefile
sed -i 's/^LDFLAGS.*/LDFLAGS=-fopenmp/' Makefile

# If LDFLAGS doesn't exist, add it
if ! grep -q "^LDFLAGS" Makefile; then
    sed -i '/^CXXFLAGS/a LDFLAGS=-fopenmp' Makefile
fi

# Update the compile command to use LDFLAGS
sed -i 's/\$(CC) \$(CXXFLAGS)/$(CC) $(CXXFLAGS) $(LDFLAGS)/' Makefile

echo "Makefile updated for OpenMP"
grep -E "CXXFLAGS|LDFLAGS" Makefile
