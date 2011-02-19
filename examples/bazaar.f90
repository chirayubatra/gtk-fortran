! This program is used to test GTK+ widgets
! Authors: Vincent Magnin, Jerry DeLisle, Tobias Burnus 
! GPL 3 licence
! To compile under Linux:
! gfortran gtk.f90 ../examples/bazaar.f90 `pkg-config --cflags --libs gtk+-2.0`


module my_widgets
  use iso_c_binding
  implicit none

  type(c_ptr) :: window
  type(c_ptr) :: box1, table
  type(c_ptr) :: button1, button2, button3, label1
  type(c_ptr) :: entry1
  type(c_ptr) :: progress, file_selector
  type(c_ptr) :: view, buffer, scrolled_window
  type(c_ptr) :: my_drawing_area, my_pixbuf
end module


module handlers
  use gtk
  use my_widgets
  implicit none
  
contains
  ! User defined event handlers go here
  function delete_event (widget, event, gdata) result(ret)  bind(c)
    use iso_c_binding, only: c_ptr, c_int, c_bool
    logical(c_bool)    :: ret
    type(c_ptr), value :: widget, event, gdata
    print *, "my delete_event"
    ret = FALSE
  end function delete_event

  function expose_event (widget, event, gdata) result(ret)  bind(c)
    use iso_c_binding, only: c_ptr, c_int, c_bool, c_char
    implicit none
    logical(c_bool)    :: ret
    type(c_ptr), value :: widget, event, gdata
    type(c_ptr) :: my_cairo_surface, my_cairo_context, my_pixbuf
    character(c_char), dimension(:), pointer :: pixel
    integer :: j
    integer :: i, nch, rowstride, width, height
    integer :: x, y
    
    print *, "my expose_event"
    my_cairo_context = gdk_cairo_create (gtk_widget_get_window(widget))
    
    call cairo_set_line_width(my_cairo_context, 1d0)
    call cairo_move_to(my_cairo_context, 100d0, 20d0)  
    call cairo_line_to(my_cairo_context, 100.5d0, 20d0)
    call cairo_stroke(my_cairo_context) 

    call cairo_set_source_rgb(my_cairo_context, 1d0, 0d0, 0d0)
    call cairo_set_line_width(my_cairo_context, 0.5d0)
    call cairo_move_to(my_cairo_context, 50d0, 0d0)  
    call cairo_line_to(my_cairo_context, 150d0, 100d0)
    call cairo_stroke(my_cairo_context) 

    call cairo_set_source_rgb(my_cairo_context, 1d0, 0d0, 0d0)
    call cairo_set_line_width(my_cairo_context, 3d0)
    call cairo_move_to(my_cairo_context, 60d0, 0d0)  
    call cairo_curve_to(my_cairo_context, 60d0, 50d0, 135d0, 45d0, 100d0, 50d0)
    call cairo_stroke(my_cairo_context) 

    !*************
    ! Pixbuffers :
    !*************
    width = 200
    height = 100
    my_pixbuf = gdk_pixbuf_new(GDK_COLORSPACE_RGB, TRUE, 8, width, height)    
    call C_F_POINTER(gdk_pixbuf_get_pixels(my_pixbuf), pixel, (/0/))

    nch = gdk_pixbuf_get_n_channels(my_pixbuf)
    rowstride = gdk_pixbuf_get_rowstride(my_pixbuf)
    print *, rowstride, nch, gdk_pixbuf_get_has_alpha(my_pixbuf)
    
    ! pixel is an array with 4 bytes per pixel (RGBA)
    ! We use chars because we need unsigned integers
    !pixel=char(255)   ! All in white and maximum opacity
    
    do i=1, width*height*nch, nch
      pixel(i)=char(0)      ! Red
      pixel(i+1)=char(0)    ! Green
      pixel(i+2)=char(255)  ! Blue
      pixel(i+3)=char(200)  ! Opacity (Alpha channel)
    end do
    
    ! (0,0) is the top left corner
    ! 0<=x<width, 0<=y<height
    
    ! Green sinus:
    do j=0, width-1
      x=j
      y=height/2 + int(50 * sin(j/10d0))
      
      i = x * nch + y * rowstride + 1
      pixel(i)=char(0)
      pixel(i+1)=char(255)
      pixel(i+2)=char(0)
      pixel(i+3)=char(255)
    end do
    
    call gdk_cairo_set_source_pixbuf(my_cairo_context, my_pixbuf, 20d0, 0d0)

    call cairo_paint(my_cairo_context)
    !************
    call cairo_set_line_width(my_cairo_context, 4d0)
    call cairo_move_to(my_cairo_context, 0d0, 0d0)
    call cairo_line_to(my_cairo_context, 100d0, 50d0)
    call cairo_stroke(my_cairo_context) 


    call cairo_destroy(my_cairo_context)
    ret = FALSE
  end function expose_event


  subroutine destroy (widget, gdata) bind(c)
    use iso_c_binding, only: c_ptr
    type(c_ptr), value :: widget, gdata
    print *, "my destroy"
    call gtk_main_quit ()
  end subroutine destroy

  function firstbutton (widget, event, gdata ) result(ret)  bind(c)
    use iso_c_binding, only: c_ptr, c_int, c_bool
    logical(c_bool)    :: ret
    type(c_ptr), value :: widget, event, gdata
        
    print *, "Hello World!"
    ret = .false.
  end function firstbutton
  
  
  function secondbutton (widget, event, gdata ) result(ret)  bind(c)
    use iso_c_binding, only: c_ptr, c_bool
    logical(c_bool)    :: ret
    type(c_ptr), value :: widget, event, gdata
    call gtk_progress_bar_pulse (progress)
    ret = .false.
  end function secondbutton


  function file_changed (widget, event, gdata ) result(ret)  bind(c)
    use iso_c_binding, only: c_ptr, c_bool, c_char
    logical(c_bool)    :: ret
    character(c_char), dimension(:), pointer :: textptr
    type(c_ptr), value :: widget, event, gdata
    character(len=512) :: my_string
    
    print *, "Selected File has changed:"
    call C_F_POINTER(gtk_file_chooser_get_filename (widget), textptr, (/0/))
    call convert_c_string(textptr, my_string)
    print *, TRIM(my_string)
    
    ret = .false.
  end function file_changed
  
  
  subroutine convert_c_string(textptr, f_string)
    use iso_c_binding, only: c_char
    implicit none
    character(c_char), dimension(:), pointer, intent(in) :: textptr
    character(len=*), intent(out) :: f_string
    integer :: i
          
    f_string=""
    i=1
    do while(textptr(i) .NE. char(0))
      f_string(i:i)=textptr(i)
      i=i+1
    end do
  end subroutine convert_c_string
end module handlers


program gtkFortran
  use iso_c_binding !, only: c_ptr, c_null_ptr, c_loc
  use gtk
  use handlers
  use my_widgets
  implicit none
  
  integer(1) :: i
  character(c_char), dimension(:), pointer :: textptr
  character(len=512) :: my_string
  
  call gtk_init ()

  ! Create the window and set up some signals for it.
  window = gtk_window_new (GTK_WINDOW_TOPLEVEL)
  !call gtk_window_set_default_size(window, 500, 500)
  call gtk_window_set_title(window, "GTK+ & Fortran are good friends"//CNULL)
  call gtk_container_set_border_width (window, 10)
  call g_signal_connect (window, "delete-event"//CNULL, c_funloc(delete_event))
  call g_signal_connect (window, "destroy"//CNULL, c_funloc(destroy))

  table = gtk_table_new (15, 3, TRUE)
  call gtk_container_add (window, table)

  button1 = gtk_button_new_with_label ("Button1"//CNULL)
  call gtk_table_attach_defaults(table, button1, 0, 1, 0, 1)
  call g_signal_connect (button1, "clicked"//CNULL, c_funloc(firstbutton))

  button2 = gtk_button_new_with_label ("Button2"//CNULL)
  call gtk_table_attach_defaults(table, button2, 1, 2, 0, 1)
  call g_signal_connect (button2, "clicked"//CNULL, c_funloc(secondbutton))

  button3 = gtk_button_new_with_label ("Exit"//CNULL)
  call gtk_table_attach_defaults(table, button3, 2, 3, 0, 1)
  call g_signal_connect (button3, "clicked"//CNULL, c_funloc(destroy))
  call g_signal_connect (button3, "clicked"//CNULL, c_funloc(firstbutton))

  label1 = gtk_label_new("My label"//CNULL)
  call gtk_table_attach_defaults(table, label1, 0, 1, 1, 2)
  
  entry1 = gtk_entry_new()
  call gtk_table_attach_defaults(table, entry1, 1, 2, 1, 2)  
  
  progress = gtk_progress_bar_new()
  call gtk_progress_bar_set_fraction (progress, 0.15d0)
  call gtk_progress_bar_set_text (progress, "My progress bar"//CNULL)
  call gtk_table_attach_defaults(table, progress, 0, 3, 2, 3)  

  view = gtk_text_view_new ()
  buffer = gtk_text_view_get_buffer (view)
  call gtk_text_buffer_set_text (buffer, "This is not clean code, just a great bazaar"//char(13)// &
      & "where I test widgets"//char(13)//"Vincent"//CNULL, -1)
  scrolled_window = gtk_scrolled_window_new (NULL, NULL)
  call gtk_container_add (scrolled_window, view)
  call gtk_table_attach_defaults(table, scrolled_window, 0, 3, 3, 6)  

  my_drawing_area = gtk_drawing_area_new()
  call g_signal_connect (my_drawing_area, "expose-event"//CNULL, c_funloc(expose_event))
  call gtk_table_attach_defaults(table, my_drawing_area, 0, 3, 6, 11)  
  
  file_selector = gtk_file_chooser_button_new ("gtk_file_chooser_button_new"//CNULL, 0)
  call gtk_table_attach_defaults(table, file_selector, 0, 3, 12, 13)  
  call g_signal_connect (file_selector, "selection_changed"//CNULL, c_funloc(file_changed));

  call gtk_widget_show_all (window)
  call gtk_main ()
 
  call C_F_POINTER(gtk_entry_get_text(entry1), textptr, (/512/))
  call convert_c_string(textptr, my_string)
  print *, my_string
  print *, TRIM(my_string)
end program gtkFortran



