<div align='center'>

```
██████╗  ██████╗ ██████╗  ██╗
██╔══██╗██╔═══██╗██╔══██╗███║
██████╔╝██║   ██║██║  ██║╚██║
██╔═══╝ ██║   ██║██║  ██║ ██║
██║     ╚██████╔╝██████╔╝ ██║
╚═╝      ╚═════╝ ╚═════╝  ╚═╝
```

</div>

## Overview :sparkles:
- https://docs.google.com/presentation/d/1rDxEwDhC16h3SyqXu0pTTeUneiPniajZnS6LJzaEl1E/edit?usp=sharing

## Development :computer:

### Requirements
- [Flutter](https://docs.flutter.dev/get-started/install)
- [Python3](https://www.python.org/downloads/)

### API Server Setup
1. Install requirements
```sh
cd api
pip install -r requirements.txt
```

2. Create `.env` file in the `/api` directory and place the necessary secrets in it (can be found in Notion).

### Run Django Server
```sh
python manage.py runserver
```
### Run Background Tasks
```sh
python manage.py process_tasks
```
