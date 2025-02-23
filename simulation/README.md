This is statring of project_Meta!

## How to prepare simulation environment?
In general we create a virtual environment, activate it, then install the required libraries and then run jupyter notebook. 

### Linux
#### Using virtualenv
* Install virtualenv: <br>
`pip install virtualenv`

* Create a virtual environment for the project: <br>
`virtualenv env_ssl_project`

* Activate virtual environment: <br>
`source env_ssl_project/bin/activate`

* Install all the required packages for the project: <br>
`pip install -r requirements.txt`

* Install jupyter in the virtualenv: <br>
`pip install jupyter`
 
* Add the virtualenv as a jupyter kernel:<br>
`ipython kernel install --name "env_ssl_project" --user` <br>
(This is to make sure that the created environment is installed in Jupyter. The `--name` value is used by Jupyter internally.) <br>

* Run jupyter notebook: <br>
`jupyter notebook` <br>

Ideally, the just-created virtual environment should automatically be selected as the running kernel in jupyter notebook. Otherwise, from `kernel --> change kernel` select env_ssl_project. <br>

#### Using conda
Install conda from the link[https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html#installing-conda-on-a-system-that-has-other-python-installations-or-packages] <br>

* Create a new environment <br>
`conda create --name env_ssl_project`

* Activate virtual environment: <br>
`conda activate env_ssl_project`


* Install all the required packages for the project: <br>
`pip install -r requirements.txt`


* Add the virtualenv as a jupyter kernel: <br>
`ipython kernel install --name "env_ssl-project" --user`

* Run jupyter notebook: <br>
`jupyter notebook`

### Windows
#### Using virtualenv
Run the following commands in windows powershell: <br>
* Install virtualenv: <br>
`pip install virtualenv`

* Create a virtual environment for the project: <br>
`virtualenv env_ssl_project`

* Activate virtual environment: <br>
`env_ssl_project\Scripts\activate`

* Install all the required packages for the project: <br>
`pip install -r requirements.txt`

* Install jupyter in the virtualenv: <br>
`pip install jupyter`

* Add the virtualenv as a jupyter kernel:<br>
`ipython kernel install --name "env_ssl_project" --user` <br>
(You can now select the created kernel `env_ssl_project` when you start Jupyter)<br>

* Run jupyter notebook: <br>
`jupyter notebook` <br>

Ideally, the just-created virtual environment should automatically be selected as the running kernel in jupyter notebook. Otherwise, from `kernel --> change kernel` select `env_ssl_project`. <br>  

