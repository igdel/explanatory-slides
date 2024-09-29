#!/bin/bash

# Enable extended globbing
shopt -s nullglob
shopt -s globstar

# Create a log file
log_file="conversion_log.txt"
echo "Conversion Log" > "$log_file"
echo "----------------" >> "$log_file"

convert_files() {
    local dir="$1"
    echo "Searching for Markdown files in: $dir"
    echo "Searching for Markdown files in: $dir" >> "$log_file"

    # Use globstar to recursively find all .md files
    for file in "$dir"/**/*.md
    do
        # Skip README.md
        if [[ "$(basename "$file")" == "README.md" ]]; then
            echo "Skipping README.md: $file"
            continue
        fi

        if [[ -f "$file" ]]; then
            filename=$(basename "${file%.*}")
            input_dir=$(dirname "$file")

            echo "Converting $file to $input_dir/${filename}.pdf"

            # Redirect both stdout and stderr to a temporary file
            temp_output=$(mktemp)

            # Change to the directory containing the Markdown file before running pandoc
            (cd "$input_dir" && pandoc -t beamer "$(basename "$file")" \
                -o "${filename}.pdf" \
                --variable=links-as-notes \
                -f markdown+link_attributes \
                --lua-filter=<(echo '
                    function Image(elem)
                        elem.attributes.width = elem.attributes.width or "0.8\\\\textwidth"
                        elem.attributes.center = elem.attributes.center or "true"
                        if elem.attributes.center == "true" then
                            return {
                                pandoc.RawInline("latex", "\\\\begin{center}"),
                                pandoc.RawInline("latex", "\\\\includegraphics[width=" .. elem.attributes.width .. "]{" .. elem.src .. "}"),
                                pandoc.RawInline("latex", "\\\\end{center}")
                            }
                        else
                            return pandoc.RawInline("latex", "\\\\includegraphics[width=" .. elem.attributes.width .. "]{" .. elem.src .. "}")
                        end
                    end
                ') \
                --resource-path=".:$PWD") > "$temp_output" 2>&1

            # Check if the conversion was successful
            if [ $? -eq 0 ]; then
                echo "Successfully converted $file to $input_dir/${filename}.pdf"
                echo "Successfully converted $file to $input_dir/${filename}.pdf" >> "$log_file"
            else
                echo "Error converting $file. Check the log for details."
                echo "Error converting $file:" >> "$log_file"
                cat "$temp_output" >> "$log_file"
                echo "----------------" >> "$log_file"
            fi

            # Remove the temporary file
            rm "$temp_output"
        fi
    done

    # Check if no files were processed
    if [[ ! -n "$(ls -A "$dir"/**/*.md 2>/dev/null)" ]]; then
        echo "No Markdown files found in $dir or its subdirectories."
        echo "No Markdown files found in $dir or its subdirectories." >> "$log_file"
    fi
}

# Start the conversion process from the current directory
convert_files "."

echo "All conversions complete! Check $log_file for details."
echo "All conversions complete!" >> "$log_file"