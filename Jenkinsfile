#!groovy

import groovy.json.JsonOutput
def notifySlack(text, channel) 
{
    def slackURL = 'B573SB58E/fVfVRGC31KZfvFAmzLLgOrSu$(SLACK_URL)/B573SB58E/fVfVRGC31KZfvFAmzLLgOrSu'
    def payload = JsonOutput.toJson([text: text,
       channel   : channel,
       username  : "jenkins",
       icon_emoji: ":jenkins:"])
    sh "curl -X POST --data-urlencode \'payload=${payload}\' ${slackURL}"
}

def checkoutSource() 
{
    // Checkout code from repository
    checkout scm

    // clean git repo, remove untracked files and git ignored files.
    sh 'git clean -fdx'
}

def build () 
{
    try 
    {
        // build fails after 5 minutes
        timeout(5) 
        {
            // make sure to have no colored output - pipeline fails otherwise
            withEnv(['FASTLANE_DISABLE_COLORS=1']) 
            {
                sh 'fastlane build'
            }
        }
    } 
    catch (e) 
    {
        currentBuild.result = 'FAILURE'
        notifySlack("Jenkins job <${env.BUILD_URL}|${env.JOB_NAME} ${env.BUILD_DISPLAY_NAME}> failed while building.", "build")
        throw e
    }
}

def test () 
{
    try 
    {
        timeout(5) 
        {
            dir('whisper-iOS')
            {
                withEnv(['FASTLANE_DISABLE_COLORS=1']) 
                {
                    sh 'fastlane test'
                }
            }
        }
    }
    catch (e) 
    {
        currentBuild.result = 'FAILURE'
        notifySlack("Jenkins job <${env.BUILD_URL}|${env.JOB_NAME} ${env.BUILD_DISPLAY_NAME}> failed while testing.", "build")
        throw e
    }
}

def afterTests()
{
    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'whisper-iOS/fastlane/test_output', reportFiles: 'report.html,report.junit', reportName: 'Test results'])
}

print 'build started, trying to reserve an iOS node'

// reserve a specific node with label
node('iOS') 
{
    stage('Checkout')
    {
        checkoutSource()
    }

    stage('Build')
    {
        build()
    }
    stage('Test')
    {
        test()
    }
    stage('Publish')
    {
        afterTests()
    }
}

print 'setting build cleaning key'
properties([[$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '5']]]);



