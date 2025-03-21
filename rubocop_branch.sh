changed_files=$(git diff --name-only development HEAD -- '*.rb')

if [ -z "$changed_files" ]; then
	echo "No Ruby or ERB files have been changed"
	exit 0
fi

echo "Running rubocop on the following files:"
echo "$changed_files"
rubocop -A $changed_files 
