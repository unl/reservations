while getopts u:p:c:s: flag
do 
    case "${flag}" in
        u) username=${OPTARG};;
        p) password=${OPTARG};;
        c) site=${OPTARG};;
        s) secret=${OPTARG};;
    esac
done
echo "{\"database\":{\"adapter\":\"mysql2\",\"host\":\"localhost\",\"username\":\"$username\",\"password\":\"$password\",\"database\":\"reservations\"},\"reCaptcha\":{\"site_key\":\"$site\",\"secret_key\":\"$secret\"},\"app\":{\"service_space_id\":\"8\",\"URL\":\"localhost:9393/\",\"cookie_domain\":\"localhost:9393/\",\"email_from\":\"innovationstudio@unl.edu\",\"cb_version\":\"2024022702\"}}" > config/server.json