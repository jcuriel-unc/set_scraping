# set_scraping
A repository for scraping and coding student evaluations of teaching

## Part 1: Identifying the sampling frame 

The goal of this project is to scrape data/comments on professors with the likely highest degree of variance for professors/instructors. We shall do that by identifying all professors at the two major public universities of Ohio State University and the University of North Carolina at Chapel Hill. Our goal shall be to identify all faculty within these departments at the schools: (1) political science, (2) psychology, (3) sociology, and (4) public health. These are chosen based upon their potential to see the mix of substantive and methodological classes and faculty characteristics likely to trigger a range of comments. In order to efficiently scrape these data, please adhere to the following steps. 

### Step 1: Log onto the program's website

Employ a google search to find the program of interest. Should be done by typing in the name of the university, followed by the name of the program/major of interest. Follow this up by looking for the directory page. This can be found either by looking for the directory as typically found under the "About" section for the major's website, the "People" tab, etc. 


![Example of OSU public health page directory link](osu_public_health_dir.png)

![Example of UNC Chapel Hill political science people link](unc_poli_sci_people.png)

### Step 2: Record faculty characteristics from university page 

Upon finding the way to the people/directory page, these faculty need to be recorded regarding their characteristics. Therefore, log into your ONU account and access the google sheet "faculty characteristics web scraping" page. For each professor that shows up, you'll want to record the information regarding: college, prof_firstname, prof_lastname, program, male, non_white, and link_rmp. The first sheet labeled "faculty" contains the data entry page, and the sheet "codebook" contains the values that the fields must take. For a given professor, simple observation and/or clicking their profile will contain the information of interest. 

## Step 3: Find Rate My Professor Link 

Click on the link to the Rate My Professor link here: 

https://www.ratemyprofessors.com/

Upon clicking the link, filter the university to the one of interest (Ohio State or University of North Carolina at Chapel Hill). 
