#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

if (!require("shiny")) install.packages("shiny")
library(shiny)
if (!require("tidyverse")) install.packages("tidyverse")
library(tibble)
if (!require("dplyr")) install.packages("dplyr")
library(dplyr)
if (!require("qcc")) install.packages("qcc")
library(qcc)
if (!require("stringr")) install.packages("stringr")
library(stringr)
options(shiny.maxRequestSize=30*1024^2)
# Define UI for application that draws a histogram


ui <- fluidPage(
  titlePanel("HPLC/GC - Calibration data"),
  sidebarPanel(position = "left", fileInput("file1", "Choose CSV File",
                                            multiple = TRUE,
                                            accept = c("text/csv",
                                                       "text/comma-separated-values,text/plain",
                                                       ".csv")),
                uiOutput("SidebarControls"),
                actionButton("update_button", "Update")
               ),
                mainPanel(h1("Control chart and data table"),
                          
                          mainPanel(
                            textOutput("selected_method"),
                            textOutput("selected_component"),
                            textOutput("file_name"),
                            plotOutput("ControlChart"),
                            tableOutput("datatable"),
                            tableOutput("datatableProcessedData")
                          )               
                ))



# Define server logic required to draw a histogram
server <- function(input, output, session) {
  file_name <- reactive({inFile <- (input$file1$datapath)})
  RawData <- reactive({RawDataInput <- as.tibble(read.csv(file=file_name(), sep=";")%>% filter(., !is.na(.$B)) %>% filter(str_detect(.$SampleName, "^Mix|^St|^ST|^Ref|^REF|^62STD|^Acet|^Benzene|^Butyl|^Chlor|^Diaceton|^Diethyl|^Diiso|^DIPEA|^DMA|^Ethanol|^Ethyl|^Hexa|^Iso|^MEK|^Methyl|^n-Hexan|^n-Propyl|^Pentan|^Propyl|^Pyridin|^TBIPE|^TEA|^tert-|^Triethyl")) %>% filter(!str_detect(.$Name, "^RRT"))) 
   # check logic, in case of errors, remove everything after ^REF
    RawDataPreProcessed <- data.frame()
    for (i in unique(RawDataInput$Sample_Set_Id)) {
      PreProcMatrix_1 <- filter(RawDataInput, RawDataInput$Sample_Set_Id == i)
       for (j in unique(PreProcMatrix_1$Name)) {
        PreProcMatrix_2 <- filter(PreProcMatrix_1, PreProcMatrix_1$Name == j)
        RawDataPreProcessed <- rbind(RawDataPreProcessed, filter(PreProcMatrix_2,PreProcMatrix_2$Result_Id == max(PreProcMatrix_2$Result_Id)))
       }
    }
    RawDataPreProcessed <- as.tibble(RawDataPreProcessed) %>% arrange(., .$Injection_Id)
    RawDataPreProcessed$Sample_Set_Name <-  str_extract(RawDataPreProcessed$Sample_Set_Name,"\\d{6}(A|B|C|D|E|F|G|H|I|J|K|L)")
    RawDataPreProcessed
    return(RawDataPreProcessed)
    })
 
  
    output$SidebarControls <- renderUI(tagList(
     selectInput(inputId = "SelectBoxMethod", label="processing method name",  choices=RawData()$Processing_Method),
     selectInput(inputId = "SelectBoxComponent", label="component",  choices=RawData()$Name)))

    
   observeEvent(input$SelectBoxMethod, {
     req(RawData())
     updateSelectInput(session, inputId = "SelectBoxComponent", label="component",  choices=RawData() %>% filter(., .$Processing_Method == input$SelectBoxMethod) %>% select(., c("Name")))})  
  
  observeEvent(input$update_button, {
   
   req(RawData())
   req(input$SelectBoxMethod)
   req(input$SelectBoxComponent)
    
   MethodName <- input$SelectBoxMethod
   ComponentName <- input$SelectBoxComponent
   if ((ComponentName !="") & (MethodName !="")) {
   if (nrow(RawData() %>% filter(., .$Processing_Method == MethodName) %>% filter(., .$Name == ComponentName)) != 0) {
     TableFiltered <- RawData() %>% filter(., .$Processing_Method == MethodName) %>% filter(., .$Name == ComponentName) %>% filter(., .$B != 0) %>% arrange(., .$Injection_Id)
   TableFilteredB <- TableFiltered$B
   output$file_name <- renderText({paste("File Name:", file_name())})
   output$selected_method <- renderText({paste("Method selected:", input$SelectBoxMethod)})
   output$selected_component <- renderText({paste("Component:", input$SelectBoxComponent)})
   output$ControlChart <- renderPlot({qcc(TableFilteredB, axes.las =3, xlab ="", label.limits = c("LCL", "UCL"), type="xbar", title = "control chart", nsigmas = 3, std.dev = sd(TableFilteredB), labels = TableFiltered$Sample_Set_Name, sizes=length(TableFilteredB))})

   output$datatable <- renderTable({as.data.frame(TableFiltered)})
   }
   }
   #output$SidebarControls <- renderUI(tagList(
    # selectInput(inputId = "SelectBoxMethod", label="processing method name",  choices=RawData()$Processing_Method, selected = MethodName),
     updateSelectInput(session, inputId = "SelectBoxComponent", label="component", selected = ComponentName,  choices=RawData() %>% filter(., .$Processing_Method == MethodName) %>% select(., c("Name")))

   
    })
  
}
  
  
  
  
  
  
  # InputBoxMethodValue <- reactive({input$SelectBoxMethod})
  # InputBoxComponentValue <- reactive({input$SelectBoxComponent})

  # 


# Run the application 
shinyApp(ui = ui, server = server)


