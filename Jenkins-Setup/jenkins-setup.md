

# Configuring Jenkins Master to Add a Slave Node  

## Step 1: Access the Jenkins Web UI  
1. Open a web browser and navigate to:  
   ```
   http://<JENKINS_MASTER_PUBLIC_IP>:8080
   ```
2. Log in with your Jenkins administrator credentials.  

## Step 2: Add a New Node (Slave)  
1. In the Jenkins dashboard, click **Manage Jenkins** from the left menu.  
2. Click **Manage Nodes and Clouds**.  
3. Click **New Node** on the left sidebar.  
4. Enter a name for the slave node (e.g., `jenkins-slave`).  
5. Select **Permanent Agent**, then click **OK**.  

## Step 3: Configure the Node  
1. **Remote root directory:** Set it to the working directory on the slave, e.g.:  
   ```
   /home/ec2-user
   ```
2. **Labels (optional):** Add any relevant labels such as `slave`, `build-agent`.  
3. **Usage:** Leave the default option (`Use this node as much as possible`).  
4. **Launch method:** Select **Launch agent via SSH**.  
5. **Host:** Enter the public IP of the Jenkins slave:  
   ```
   <JENKINS_SLAVE_PUBLIC_IP>
   ```

## Step 4: Configure SSH Credentials  
1. Click **Add** → **Jenkins** (under the Credentials section).  
2. Select **SSH Username with private key**.  
3. Enter the following details:  
   - **Username:** `ec2-user`  
   - **Private Key:**  
     - Select **Enter directly**  
     - Paste the contents of `jenkins-login.pem`  
4. Click **Add** to save the credentials.  

## Step 5: Finalize Configuration  
1. In the Node configuration, select the SSH credentials you just created.  
2. Click **Save and Launch** to initiate the connection.  

---

## SSH Key Configuration for Secure Connection  

- **Jenkins Master:** Must keep the **private key** securely stored.  
- **Jenkins Slave:** Should store the **public key** of the Jenkins master in the `~/.ssh/authorized_keys` file to allow authentication.  

---

This version ensures clarity, readability, and proper structuring for easier understanding. Let me know if you need further refinements! 🚀