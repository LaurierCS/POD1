# Generated by Django 5.0.3 on 2024-03-27 21:25

import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='UploadedAudio',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('entry_title', models.CharField(default='', max_length=250)),
                ('emotions', models.CharField(default='', max_length=250)),
                ('recording', models.FileField(upload_to='recordings')),
                ('uploaded_on', models.DateTimeField(auto_now_add=True)),
            ],
        ),
    ]