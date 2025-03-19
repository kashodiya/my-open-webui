import datetime

# Define a dictionary to store the appointments
appointments = {}

def add_appointment(date, time, description):
    """
    Add a new appointment to the calendar.
    
    Args:
        date (str): The date of the appointment in the format 'YYYY-MM-DD'.
        time (str): The time of the appointment in the format 'HH:MM'.
        description (str): A brief description of the appointment.
    """
    if date not in appointments:
        appointments[date] = []
    appointments[date].append((time, description))
    print(f"Appointment added: {date} at {time} - {description}")

def view_appointments(date=None):
    """
    View the appointments for a specific date or all appointments.
    
    Args:
        date (str, optional): The date to view appointments for in the format 'YYYY-MM-DD'. If not provided, all appointments will be shown.
    """
    if date:
        if date in appointments:
            print(f"Appointments for {date}:")
            for time, description in appointments[date]:
                print(f"{time} - {description}")
        else:
            print(f"No appointments found for {date}.")
    else:
        print("All Appointments:")
        for date, appointments_on_date in appointments.items():
            print(f"{date}:")
            for time, description in appointments_on_date:
                print(f"{time} - {description}")

def main():
    """
    The main function to interact with the calendar application.
    """
    while True:
        print("\nCalendar App Menu:")
        print("1. Add Appointment")
        print("2. View Appointments")
        print("3. Exit")
        
        choice = input("Enter your choice (1-3): ")
        
        if choice == "1":
            date = input("Enter the date (YYYY-MM-DD): ")
            time = input("Enter the time (HH:MM): ")
            description = input("Enter the appointment description: ")
            add_appointment(date, time, description)
        elif choice == "2":
            date = input("Enter the date (YYYY-MM-DD) [leave blank to view all]: ")
            view_appointments(date)
        elif choice == "3":
            print("Exiting Calendar App...")
            break
        else:
            print("Invalid choice. Please try again.")

if __name__ == "__main__":
    main()